# Contributing to Discord Stock Alert Bot

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different viewpoints and experiences

## Getting Started

### Prerequisites

- Python 3.11 or higher
- Git
- A GitHub account
- Basic understanding of Python and Discord bots

### Setting Up Your Development Environment

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/discord-stock-alert-bot.git
   cd discord-stock-alert-bot
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/loganngarcia/discord-stock-alert-bot.git
   ```

4. **Create a virtual environment**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

5. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   pip install -r requirements-dev.txt  # If it exists
   ```

6. **Set up pre-commit hooks** (optional but recommended):
   ```bash
   pip install pre-commit
   pre-commit install
   ```

## Development Workflow

### Branch Naming

Use descriptive branch names:
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring
- `test/description` - Test additions/updates

### Making Changes

1. **Create a new branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Write clean, readable code
   - Follow the coding standards
   - Add tests for new features
   - Update documentation as needed

3. **Test your changes**:
   ```bash
   pytest test_bot.py -v
   python bot.py  # Test manually if needed
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

   Use conventional commit messages:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `style:` - Code style changes (formatting, etc.)
   - `refactor:` - Code refactoring
   - `test:` - Test additions/changes
   - `chore:` - Maintenance tasks

5. **Keep your branch up to date**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

6. **Push your changes**:
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### Python Style Guide

- Follow [PEP 8](https://peps.python.org/pep-0008/) style guidelines
- Use type hints where appropriate
- Write docstrings for all functions and classes
- Keep functions focused and small
- Use meaningful variable and function names

### Code Formatting

We recommend using:
- `black` for code formatting
- `flake8` or `pylint` for linting
- `mypy` for type checking

Example:
```bash
black bot.py
flake8 bot.py
mypy bot.py
```

### Documentation

- All public functions and classes must have docstrings
- Use Google-style docstrings:
  ```python
  def calculate_anchor(targets: List[float], consensus: Optional[float], haircut: float) -> Tuple[float, str]:
      """
      Calculate trimmed-and-haircut anchor price.
      
      Args:
          targets: List of analyst price targets
          consensus: Consensus target if <3 individual targets
          haircut: Haircut rate (e.g., 0.125 for 12.5%)
      
      Returns:
          Tuple of (anchor_price, calculation_method)
      """
  ```

## Testing

### Writing Tests

- Write tests for all new features
- Aim for high test coverage
- Test edge cases and error conditions
- Use descriptive test names

Example:
```python
def test_calculate_anchor_with_three_targets():
    """Test anchor calculation with exactly 3 targets."""
    targets = [10.0, 15.0, 20.0]
    anchor, method = calculate_anchor(targets, None, 0.125)
    assert anchor == pytest.approx(13.125)
    assert method == "trimmed"
```

### Running Tests

```bash
# Run all tests
pytest test_bot.py -v

# Run with coverage
pytest test_bot.py --cov=bot --cov-report=html

# Run specific test
pytest test_bot.py::test_threshold_alert_trigger -v
```

## Pull Request Process

1. **Ensure your code follows the standards**:
   - All tests pass
   - Code is properly formatted
   - Documentation is updated
   - No secrets are committed

2. **Update CHANGELOG.md** if applicable

3. **Create a pull request**:
   - Use a clear, descriptive title
   - Fill out the PR template
   - Reference any related issues
   - Add screenshots if UI changes

4. **Respond to feedback**:
   - Address review comments promptly
   - Make requested changes
   - Keep the PR focused and small

5. **Wait for review**:
   - Maintainers will review your PR
   - Address any requested changes
   - Once approved, your PR will be merged

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

- **Description**: Clear description of the bug
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Environment**: Python version, OS, etc.
- **Logs**: Relevant error messages or logs

### Feature Requests

When requesting features, please include:

- **Use Case**: Why this feature would be useful
- **Proposed Solution**: How you envision it working
- **Alternatives**: Other solutions you've considered

## Questions?

If you have questions about contributing:

- Open an issue with the `question` label
- Check existing documentation in `docs/`
- Review existing code and tests for examples

Thank you for contributing! 🎉
